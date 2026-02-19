// src/modules/chat/components/ChatWindow.tsx
export const ChatWindow = () => {
  const [messages, setMessages] = useState([]);

  const askQuestion = async (query: string) => {
    const response = await fetch('/api/rag/query', {
      method: 'POST',
      body: JSON.stringify({ query })
    });

    const reader = response.body?.getReader();
    // Стрімінг відповіді (SSE) для кращого UX
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const text = new TextDecoder().decode(value);
      updateLastMessage(text); // Додавання тексту по мірі надходження
    }
  };

  return (
    <div className="chat-container bg-slate-50 p-4">
      {/* Рендеринг повідомлень */}
    </div>
  );
};